import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a scheduled care protocol profile.
    final class ScheduledCareProtocolProfileView {
        var codeText: String
        var name: String
        var rateText: String
        var diagnosisCodeText: String
        var regionText: String
        var statusLabel: String

        init(codeText: String, name: String, rateText: String, diagnosisCodeText: String, regionText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.rateText = rateText
            self.diagnosisCodeText = diagnosisCodeText
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledCareProtocolProfileView(_ item: ScheduledCareProtocolProfile) -> ScheduledCareProtocolProfileView {
        return ScheduledCareProtocolProfileView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            rateText: String(format: "%.2f", item.rate),
            diagnosisCodeText: item.diagnosisCode,
            regionText: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledCareProtocolProfileViews(_ items: [ScheduledCareProtocolProfile]) -> [ScheduledCareProtocolProfileView] {
        var views: [ScheduledCareProtocolProfileView] = []
        for item in items {
            views.append(toScheduledCareProtocolProfileView(item))
        }
        return views
    }

    static func sumScheduledCareProtocolProfileView(_ view: ScheduledCareProtocolProfileView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedRate
    }
}
