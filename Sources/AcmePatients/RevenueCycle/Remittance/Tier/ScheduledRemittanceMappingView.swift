import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a scheduled remittance mapping.
    final class ScheduledRemittanceMappingView {
        var code: String
        var nameText: String
        var clinicianID: String
        var visitMinutesText: String
        var dosageMgText: String
        var minimum: String
        var visible: String
        var title: String
        var batchSize: String
        var statusLabel: String

        init(code: String, nameText: String, clinicianID: String, visitMinutesText: String, dosageMgText: String, minimum: String, visible: String, title: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.clinicianID = clinicianID
            self.visitMinutesText = visitMinutesText
            self.dosageMgText = dosageMgText
            self.minimum = minimum
            self.visible = visible
            self.title = title
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledRemittanceMappingView(_ item: ScheduledRemittanceMapping) -> ScheduledRemittanceMappingView {
        return ScheduledRemittanceMappingView(
            code: item.code,
            nameText: item.name,
            clinicianID: item.clinicianID,
            visitMinutesText: String(item.visitMinutes),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            minimum: String(format: "%.2f", item.minimum),
            visible: "\(item.visible)",
            title: item.title,
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledRemittanceMappingViews(_ items: [ScheduledRemittanceMapping]) -> [ScheduledRemittanceMappingView] {
        var views: [ScheduledRemittanceMappingView] = []
        for item in items {
            views.append(toScheduledRemittanceMappingView(item))
        }
        return views
    }

    static func sumScheduledRemittanceMappingView(_ view: ScheduledRemittanceMappingView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedVisitMinutes) + parsedDosageMg + parsedMinimum
    }
}
