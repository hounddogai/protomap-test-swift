import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a default program estimate.
    final class DefaultProgramEstimateView {
        var codeText: String
        var name: String
        var segmentText: String
        var summary: String
        var procedureCode: String
        var specialtyText: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, name: String, segmentText: String, summary: String, procedureCode: String, specialtyText: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.segmentText = segmentText
            self.summary = summary
            self.procedureCode = procedureCode
            self.specialtyText = specialtyText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultProgramEstimateView(_ item: DefaultProgramEstimate) -> DefaultProgramEstimateView {
        return DefaultProgramEstimateView(
            codeText: item.code,
            name: item.name,
            segmentText: item.segment,
            summary: item.summary,
            procedureCode: item.procedureCode,
            specialtyText: Kit.Text.truncate(item.specialty, limit: 40),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultProgramEstimateViews(_ items: [DefaultProgramEstimate]) -> [DefaultProgramEstimateView] {
        var views: [DefaultProgramEstimateView] = []
        for item in items {
            views.append(toDefaultProgramEstimateView(item))
        }
        return views
    }

    static func sumDefaultProgramEstimateView(_ view: DefaultProgramEstimateView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
