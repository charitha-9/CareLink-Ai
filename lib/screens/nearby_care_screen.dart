import 'package:flutter/material.dart';
import '../models/care_facility_model.dart';
import '../services/nearby_care_service.dart';
import '../theme/app_theme.dart';
import '../widgets/care_facility_card.dart';
import '../widgets/carelink_states.dart';
import 'facility_details_screen.dart';

/// Dedicated Care Navigation screen for locating nearby Hospitals,
/// Clinics, and Campus Health Centers.
class NearbyCareScreen extends StatefulWidget {
  final CareFacilityType? initialFilter;
  final NearbyCareService? service;

  const NearbyCareScreen({
    super.key,
    this.initialFilter,
    this.service,
  });

  @override
  State<NearbyCareScreen> createState() => _NearbyCareScreenState();
}

class _NearbyCareScreenState extends State<NearbyCareScreen>
    with SingleTickerProviderStateMixin {
  late final NearbyCareService _careService;
  late final TabController _tabController;

  final TextEditingController _searchController = TextEditingController();

  List<CareFacility> _facilities = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter indices: 0 = All, 1 = Hospitals, 2 = Clinics
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _careService = widget.service ?? NearbyCareService.instance;

    int initialIndex = 0;
    if (widget.initialFilter == CareFacilityType.hospital) {
      initialIndex = 1;
    } else if (widget.initialFilter == CareFacilityType.clinic) {
      initialIndex = 2;
    }
    _selectedTabIndex = initialIndex;

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_handleTabChange);

    _loadFacilities();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging ||
        _tabController.index == _selectedTabIndex) {
      return;
    }
    setState(() {
      _selectedTabIndex = _tabController.index;
    });
    _loadFacilities();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  CareFacilityType? get _activeTypeFilter {
    switch (_selectedTabIndex) {
      case 1:
        return CareFacilityType.hospital;
      case 2:
        return CareFacilityType.clinic;
      default:
        return null;
    }
  }

  Future<void> _loadFacilities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _careService.getFacilities(
        typeFilter: _activeTypeFilter,
        searchQuery: _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _facilities = results;
          _isLoading = false;
        });
      }
    } on NearbyCareException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred while loading facilities: $e';
        });
      }
    }
  }

  void _openDetails(CareFacility facility) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FacilityDetailsScreen(facility: facility),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Care Navigation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh facilities',
            onPressed: _loadFacilities,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'All Facilities'),
                Tab(text: 'Hospitals'),
                Tab(text: 'Clinics'),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: Column(
            children: [
              // Search input box
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMd,
                  AppTheme.spacingSm,
                  AppTheme.spacingMd,
                  AppTheme.spacingSm,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _loadFacilities(),
                  decoration: InputDecoration(
                    hintText: 'Search by facility name or address...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.textMuted,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _loadFacilities();
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              const Divider(height: 1, color: AppTheme.borderLight),

              // Location context bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: 8,
                ),
                color: AppTheme.primaryLight.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.my_location_rounded,
                      size: 14,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _careService.hasLiveLocation
                            ? 'Using GPS device location'
                            : 'Near Amity University Campus (Sector 125, Noida)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                    Text(
                      '${_facilities.length} found',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),

              // Body content: Loading / Error / Empty / List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadFacilities,
                  color: AppTheme.primary,
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const CareLinkLoadingView();
    }

    if (_errorMessage != null) {
      return CareLinkErrorView(
        message: _errorMessage!,
        onRetry: _loadFacilities,
      );
    }

    if (_facilities.isEmpty) {
      return CareLinkEmptyView(
        title: 'No Facilities Found',
        message: _searchController.text.isNotEmpty
            ? 'No medical facilities matching "${_searchController.text}". Try clearing your search.'
            : 'No nearby healthcare facilities found in the current radius.',
        actionLabel: _searchController.text.isNotEmpty ? 'Clear Search' : 'Refresh',
        onAction: () {
          if (_searchController.text.isNotEmpty) {
            _searchController.clear();
          }
          _loadFacilities();
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: _facilities.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingSm),
      itemBuilder: (context, index) {
        final facility = _facilities[index];
        return CareFacilityCard(
          facility: facility,
          onTap: () => _openDetails(facility),
        );
      },
    );
  }
}
