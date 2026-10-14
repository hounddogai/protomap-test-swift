import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a global read mapping.
    final class GlobalReadMappingView {
        var codeText: String
        var labelText: String
        var cost: String
        var clinicianID: String
        var regionText: String
        var version: String
        var statusLabel: String

        init(codeText: String, labelText: String, cost: String, clinicianID: String, regionText: String, version: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.cost = cost
            self.clinicianID = clinicianID
            self.regionText = regionText
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalReadMappingView(_ item: GlobalReadMapping) -> GlobalReadMappingView {
        return GlobalReadMappingView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            labelText: Kit.Text.truncate(item.label, limit: 64),
            cost: String(format: "%.2f", item.cost),
            clinicianID: item.clinicianID,
            regionText: Kit.Text.truncate(item.region, limit: 64),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalReadMappingViews(_ items: [GlobalReadMapping]) -> [GlobalReadMappingView] {
        var views: [GlobalReadMappingView] = []
        for item in items {
            views.append(toGlobalReadMappingView(item))
        }
        return views
    }

    static func sumGlobalReadMappingView(_ view: GlobalReadMappingView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedCost + Double(parsedVersion)
    }
}
