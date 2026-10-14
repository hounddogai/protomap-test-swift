import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a fallback transfer template.
    final class FallbackTransferTemplateView {
        var code: String
        var title: String
        var country: String
        var dosageMg: String
        var createdAt: String
        var floorValue: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, title: String, country: String, dosageMg: String, createdAt: String, floorValue: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.country = country
            self.dosageMg = dosageMg
            self.createdAt = createdAt
            self.floorValue = floorValue
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackTransferTemplateView(_ item: FallbackTransferTemplate) -> FallbackTransferTemplateView {
        return FallbackTransferTemplateView(
            code: item.code,
            title: item.title,
            country: item.country,
            dosageMg: String(format: "%.2f", item.dosageMg),
            createdAt: String(item.createdAt),
            floorValue: String(format: "%.2f", item.floorValue),
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackTransferTemplateViews(_ items: [FallbackTransferTemplate]) -> [FallbackTransferTemplateView] {
        var views: [FallbackTransferTemplateView] = []
        for item in items {
            views.append(toFallbackTransferTemplateView(item))
        }
        return views
    }

    static func sumFallbackTransferTemplateView(_ view: FallbackTransferTemplateView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedDosageMg + Double(parsedCreatedAt) + parsedFloorValue
    }
}
