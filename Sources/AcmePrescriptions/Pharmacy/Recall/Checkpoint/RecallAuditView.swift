import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall audit.
    final class RecallAuditView {
        var code: String
        var label: String
        var acuity: String
        var localeText: String
        var priority: String
        var checksum: String
        var descriptionText: String
        var active: String
        var titleText: String
        var refills: String
        var batchSize: String
        var statusLabel: String

        init(code: String, label: String, acuity: String, localeText: String, priority: String, checksum: String, descriptionText: String, active: String, titleText: String, refills: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.localeText = localeText
            self.priority = priority
            self.checksum = checksum
            self.descriptionText = descriptionText
            self.active = active
            self.titleText = titleText
            self.refills = refills
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toRecallAuditView(_ item: RecallAudit) -> RecallAuditView {
        return RecallAuditView(
            code: item.code,
            label: item.label,
            acuity: String(item.acuity),
            localeText: item.locale,
            priority: String(item.priority),
            checksum: item.checksum,
            descriptionText: item.description,
            active: "\(item.active)",
            titleText: item.title,
            refills: String(item.refills),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallAuditViews(_ items: [RecallAudit]) -> [RecallAuditView] {
        var views: [RecallAuditView] = []
        for item in items {
            views.append(toRecallAuditView(item))
        }
        return views
    }

    static func sumRecallAuditView(_ view: RecallAuditView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedAcuity) + Double(parsedPriority) + Double(parsedRefills)
    }
}
