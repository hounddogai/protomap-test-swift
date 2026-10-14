import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy profile.
    final class ProxyProfileView {
        var codeText: String
        var title: String
        var country: String
        var ratio: String
        var diagnosisCodeText: String
        var region: String
        var name: String
        var facility: String
        var version: String
        var threshold: String
        var statusLabel: String

        init(codeText: String, title: String, country: String, ratio: String, diagnosisCodeText: String, region: String, name: String, facility: String, version: String, threshold: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.country = country
            self.ratio = ratio
            self.diagnosisCodeText = diagnosisCodeText
            self.region = region
            self.name = name
            self.facility = facility
            self.version = version
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toProxyProfileView(_ item: ProxyProfile) -> ProxyProfileView {
        return ProxyProfileView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            country: item.country,
            ratio: String(format: "%.2f", item.ratio),
            diagnosisCodeText: item.diagnosisCode,
            region: Kit.Text.truncate(item.region, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 40),
            facility: item.facility,
            version: String(item.version),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyProfileViews(_ items: [ProxyProfile]) -> [ProxyProfileView] {
        var views: [ProxyProfileView] = []
        for item in items {
            views.append(toProxyProfileView(item))
        }
        return views
    }

    static func sumProxyProfileView(_ view: ProxyProfileView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedRatio + Double(parsedVersion) + parsedThreshold
    }
}
