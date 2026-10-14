import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up notice.
    final class FollowUpNoticeView {
        var code: String
        var name: String
        var version: String
        var dosageMg: String
        var reviewer: String
        var diagnosisCodeText: String
        var quantity: String
        var statusLabel: String

        init(code: String, name: String, version: String, dosageMg: String, reviewer: String, diagnosisCodeText: String, quantity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.version = version
            self.dosageMg = dosageMg
            self.reviewer = reviewer
            self.diagnosisCodeText = diagnosisCodeText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpNoticeView(_ item: FollowUpNotice) -> FollowUpNoticeView {
        return FollowUpNoticeView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            version: String(item.version),
            dosageMg: String(format: "%.2f", item.dosageMg),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 120),
            diagnosisCodeText: item.diagnosisCode,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpNoticeViews(_ items: [FollowUpNotice]) -> [FollowUpNoticeView] {
        var views: [FollowUpNoticeView] = []
        for item in items {
            views.append(toFollowUpNoticeView(item))
        }
        return views
    }

    static func sumFollowUpNoticeView(_ view: FollowUpNoticeView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedVersion) + parsedDosageMg + Double(parsedQuantity)
    }
}
