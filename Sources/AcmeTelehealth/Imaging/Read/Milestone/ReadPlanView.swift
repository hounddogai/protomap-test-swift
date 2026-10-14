import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read plan.
    final class ReadPlanView {
        var code: String
        var title: String
        var procedureCode: String
        var threshold: String
        var retries: String
        var phone: String
        var dosageMg: String
        var quantityText: String
        var floorValue: String
        var expiresAtText: String
        var facility: String
        var statusLabel: String

        init(code: String, title: String, procedureCode: String, threshold: String, retries: String, phone: String, dosageMg: String, quantityText: String, floorValue: String, expiresAtText: String, facility: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.threshold = threshold
            self.retries = retries
            self.phone = phone
            self.dosageMg = dosageMg
            self.quantityText = quantityText
            self.floorValue = floorValue
            self.expiresAtText = expiresAtText
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toReadPlanView(_ item: ReadPlan) -> ReadPlanView {
        return ReadPlanView(
            code: item.code,
            title: item.title,
            procedureCode: item.procedureCode,
            threshold: String(format: "%.2f", item.threshold),
            retries: String(item.retries),
            phone: item.phone,
            dosageMg: String(format: "%.2f", item.dosageMg),
            quantityText: String(item.quantity),
            floorValue: String(format: "%.2f", item.floorValue),
            expiresAtText: String(item.expiresAt),
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadPlanViews(_ items: [ReadPlan]) -> [ReadPlanView] {
        var views: [ReadPlanView] = []
        for item in items {
            views.append(toReadPlanView(item))
        }
        return views
    }

    static func sumReadPlanView(_ view: ReadPlanView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedThreshold + Double(parsedRetries) + parsedDosageMg
    }
}
