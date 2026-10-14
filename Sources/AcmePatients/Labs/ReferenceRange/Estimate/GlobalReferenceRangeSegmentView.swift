import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a global reference range segment.
    final class GlobalReferenceRangeSegmentView {
        var code: String
        var labelText: String
        var specialty: String
        var externalRefText: String
        var channel: String
        var discountText: String
        var categoryText: String
        var patientRefText: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, labelText: String, specialty: String, externalRefText: String, channel: String, discountText: String, categoryText: String, patientRefText: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.specialty = specialty
            self.externalRefText = externalRefText
            self.channel = channel
            self.discountText = discountText
            self.categoryText = categoryText
            self.patientRefText = patientRefText
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalReferenceRangeSegmentView(_ item: GlobalReferenceRangeSegment) -> GlobalReferenceRangeSegmentView {
        return GlobalReferenceRangeSegmentView(
            code: item.code,
            labelText: item.label,
            specialty: Kit.Text.truncate(item.specialty, limit: 120),
            externalRefText: item.externalRef,
            channel: Kit.Text.truncate(item.channel, limit: 80),
            discountText: String(format: "%.2f", item.discount),
            categoryText: Kit.Text.truncate(item.category, limit: 80),
            patientRefText: item.patientRef,
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalReferenceRangeSegmentViews(_ items: [GlobalReferenceRangeSegment]) -> [GlobalReferenceRangeSegmentView] {
        var views: [GlobalReferenceRangeSegmentView] = []
        for item in items {
            views.append(toGlobalReferenceRangeSegmentView(item))
        }
        return views
    }

    static func sumGlobalReferenceRangeSegmentView(_ view: GlobalReferenceRangeSegmentView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedDiscount
    }
}
