import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a rolling closure profile.
    final class RollingClosureProfileView {
        var code: String
        var title: String
        var wardText: String
        var diagnosisCode: String
        var cost: String
        var dosageMg: String
        var sequenceText: String
        var statusLabel: String

        init(code: String, title: String, wardText: String, diagnosisCode: String, cost: String, dosageMg: String, sequenceText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.wardText = wardText
            self.diagnosisCode = diagnosisCode
            self.cost = cost
            self.dosageMg = dosageMg
            self.sequenceText = sequenceText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingClosureProfileView(_ item: RollingClosureProfile) -> RollingClosureProfileView {
        return RollingClosureProfileView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            wardText: item.ward,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            cost: String(format: "%.2f", item.cost),
            dosageMg: String(format: "%.2f", item.dosageMg),
            sequenceText: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingClosureProfileViews(_ items: [RollingClosureProfile]) -> [RollingClosureProfileView] {
        var views: [RollingClosureProfileView] = []
        for item in items {
            views.append(toRollingClosureProfileView(item))
        }
        return views
    }

    static func sumRollingClosureProfileView(_ view: RollingClosureProfileView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedCost + parsedDosageMg + Double(parsedSequence)
    }
}
