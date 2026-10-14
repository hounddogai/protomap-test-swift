import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool bundle.
    final class FloatPoolBundleView {
        var codeText: String
        var label: String
        var ratio: String
        var ownerIDText: String
        var versionText: String
        var statusLabel: String

        init(codeText: String, label: String, ratio: String, ownerIDText: String, versionText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.ratio = ratio
            self.ownerIDText = ownerIDText
            self.versionText = versionText
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolBundleView(_ item: FloatPoolBundle) -> FloatPoolBundleView {
        return FloatPoolBundleView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            ratio: String(format: "%.2f", item.ratio),
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 40),
            versionText: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolBundleViews(_ items: [FloatPoolBundle]) -> [FloatPoolBundleView] {
        var views: [FloatPoolBundleView] = []
        for item in items {
            views.append(toFloatPoolBundleView(item))
        }
        return views
    }

    static func sumFloatPoolBundleView(_ view: FloatPoolBundleView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedRatio + Double(parsedVersion)
    }
}
