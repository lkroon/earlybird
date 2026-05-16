import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../models/site.dart';

/// A dropdown widget for selecting the current scraping site
class SiteSelector extends StatelessWidget {
  final Site selectedSite;
  final ValueChanged<Site> onSiteChanged;

  const SiteSelector({
    super.key,
    required this.selectedSite,
    required this.onSiteChanged,
  });

  Widget _buildSiteLogo(Site site, {double height = 24}) {
    if (site.isSvg) {
      return SvgPicture.asset(
        site.logoPath,
        height: height,
      );
    } else {
      return Image.asset(
        site.logoPath,
        height: height,
        fit: BoxFit.contain,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(selectedSite.backgroundColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Site>(
          value: selectedSite,
          icon: Icon(
            Icons.arrow_drop_down,
            color: selectedSite == Site.indeed ? Colors.black87 : Colors.white,
          ),
          borderRadius: BorderRadius.circular(8),
          items: Site.values.map((site) {
            return DropdownMenuItem<Site>(
              value: site,
              enabled: site.isImplemented,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Color(site.backgroundColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSiteLogo(site, height: 20),
                    if (!site.isImplemented) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.lock,
                        size: 16,
                        color:
                            site == Site.indeed ? Colors.grey : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (Site? newSite) {
            if (newSite != null && newSite.isImplemented) {
              onSiteChanged(newSite);
            }
          },
        ),
      ),
    );
  }
}
