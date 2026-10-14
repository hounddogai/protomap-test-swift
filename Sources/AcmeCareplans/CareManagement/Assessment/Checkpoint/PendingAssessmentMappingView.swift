import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a pending assessment mapping.
    final class PendingAssessmentMappingView {
        var codeText: String
        var labelText: String
        var archived: String
        var minimumText: String
        var thresholdText: String
        var phone: String
        var ward: String
        var contactEmail: String
        var nameText: String
        var locale: String
        var statusLabel: String

        init(codeText: String, labelText: String, archived: String, minimumText: String, thresholdText: String, phone: String, ward: String, contactEmail: String, nameText: String, locale: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.archived = archived
            self.minimumText = minimumText
            self.thresholdText = thresholdText
            self.phone = phone
            self.ward = ward
            self.contactEmail = contactEmail
            self.nameText = nameText
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toPendingAssessmentMappingView(_ item: PendingAssessmentMapping) -> PendingAssessmentMappingView {
        return PendingAssessmentMappingView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            archived: "\(item.archived)",
            minimumText: String(format: "%.2f", item.minimum),
            thresholdText: String(format: "%.2f", item.threshold),
            phone: Kit.Text.truncate(item.phone, limit: 64),
            ward: item.ward,
            contactEmail: item.contactEmail,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingAssessmentMappingViews(_ items: [PendingAssessmentMapping]) -> [PendingAssessmentMappingView] {
        var views: [PendingAssessmentMappingView] = []
        for item in items {
            views.append(toPendingAssessmentMappingView(item))
        }
        return views
    }

    static func sumPendingAssessmentMappingView(_ view: PendingAssessmentMappingView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedMinimum + parsedThreshold
    }
}
