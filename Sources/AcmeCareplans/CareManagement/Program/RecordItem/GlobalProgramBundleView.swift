import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a global program bundle.
    final class GlobalProgramBundleView {
        var code: String
        var label: String
        var capacity: String
        var ceiling: String
        var region: String
        var statusLabel: String

        init(code: String, label: String, capacity: String, ceiling: String, region: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.ceiling = ceiling
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalProgramBundleView(_ item: GlobalProgramBundle) -> GlobalProgramBundleView {
        return GlobalProgramBundleView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            capacity: String(item.capacity),
            ceiling: String(format: "%.2f", item.ceiling),
            region: Kit.Text.truncate(item.region, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalProgramBundleViews(_ items: [GlobalProgramBundle]) -> [GlobalProgramBundleView] {
        var views: [GlobalProgramBundleView] = []
        for item in items {
            views.append(toGlobalProgramBundleView(item))
        }
        return views
    }

    static func sumGlobalProgramBundleView(_ view: GlobalProgramBundleView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedCapacity) + parsedCeiling
    }
}
