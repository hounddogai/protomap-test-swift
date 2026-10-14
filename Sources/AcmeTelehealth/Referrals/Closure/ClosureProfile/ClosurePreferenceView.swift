import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure preference.
    final class ClosurePreferenceView {
        var code: String
        var title: String
        var capacity: String
        var payer: String
        var region: String
        var wardText: String
        var versionText: String
        var score: String
        var budget: String
        var diagnosisCode: String
        var patientRefText: String
        var statusLabel: String

        init(code: String, title: String, capacity: String, payer: String, region: String, wardText: String, versionText: String, score: String, budget: String, diagnosisCode: String, patientRefText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.payer = payer
            self.region = region
            self.wardText = wardText
            self.versionText = versionText
            self.score = score
            self.budget = budget
            self.diagnosisCode = diagnosisCode
            self.patientRefText = patientRefText
            self.statusLabel = statusLabel
        }
    }

    static func toClosurePreferenceView(_ item: ClosurePreference) -> ClosurePreferenceView {
        return ClosurePreferenceView(
            code: item.code,
            title: item.title,
            capacity: String(item.capacity),
            payer: Kit.Text.truncate(item.payer, limit: 80),
            region: Kit.Text.truncate(item.region, limit: 120),
            wardText: Kit.Text.truncate(item.ward, limit: 64),
            versionText: String(item.version),
            score: String(format: "%.2f", item.score),
            budget: String(format: "%.2f", item.budget),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            patientRefText: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosurePreferenceViews(_ items: [ClosurePreference]) -> [ClosurePreferenceView] {
        var views: [ClosurePreferenceView] = []
        for item in items {
            views.append(toClosurePreferenceView(item))
        }
        return views
    }

    static func sumClosurePreferenceView(_ view: ClosurePreferenceView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedCapacity) + Double(parsedVersion) + parsedScore
    }
}
