import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a global float pool target.
    final class GlobalFloatPoolTargetView {
        var code: String
        var name: String
        var diagnosisCodeText: String
        var refillsText: String
        var rate: String
        var graceDaysText: String
        var bedText: String
        var startsAt: String
        var channelText: String
        var reviewer: String
        var statusLabel: String

        init(code: String, name: String, diagnosisCodeText: String, refillsText: String, rate: String, graceDaysText: String, bedText: String, startsAt: String, channelText: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.diagnosisCodeText = diagnosisCodeText
            self.refillsText = refillsText
            self.rate = rate
            self.graceDaysText = graceDaysText
            self.bedText = bedText
            self.startsAt = startsAt
            self.channelText = channelText
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalFloatPoolTargetView(_ item: GlobalFloatPoolTarget) -> GlobalFloatPoolTargetView {
        return GlobalFloatPoolTargetView(
            code: item.code,
            name: item.name,
            diagnosisCodeText: item.diagnosisCode,
            refillsText: String(item.refills),
            rate: String(format: "%.2f", item.rate),
            graceDaysText: String(item.graceDays),
            bedText: Kit.Text.truncate(item.bed, limit: 40),
            startsAt: String(item.startsAt),
            channelText: item.channel,
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalFloatPoolTargetViews(_ items: [GlobalFloatPoolTarget]) -> [GlobalFloatPoolTargetView] {
        var views: [GlobalFloatPoolTargetView] = []
        for item in items {
            views.append(toGlobalFloatPoolTargetView(item))
        }
        return views
    }

    static func sumGlobalFloatPoolTargetView(_ view: GlobalFloatPoolTargetView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedRefills) + parsedRate + Double(parsedGraceDays)
    }
}
