import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a fallback courier segment.
    final class FallbackCourierSegmentView {
        var codeText: String
        var title: String
        var reviewerText: String
        var country: String
        var clinicianID: String
        var margin: String
        var facility: String
        var checksumText: String
        var dosageMgText: String
        var statusLabel: String

        init(codeText: String, title: String, reviewerText: String, country: String, clinicianID: String, margin: String, facility: String, checksumText: String, dosageMgText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.reviewerText = reviewerText
            self.country = country
            self.clinicianID = clinicianID
            self.margin = margin
            self.facility = facility
            self.checksumText = checksumText
            self.dosageMgText = dosageMgText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackCourierSegmentView(_ item: FallbackCourierSegment) -> FallbackCourierSegmentView {
        return FallbackCourierSegmentView(
            codeText: item.code,
            title: item.title,
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 80),
            country: Kit.Text.truncate(item.country, limit: 64),
            clinicianID: item.clinicianID,
            margin: String(format: "%.2f", item.margin),
            facility: item.facility,
            checksumText: item.checksum,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackCourierSegmentViews(_ items: [FallbackCourierSegment]) -> [FallbackCourierSegmentView] {
        var views: [FallbackCourierSegmentView] = []
        for item in items {
            views.append(toFallbackCourierSegmentView(item))
        }
        return views
    }

    static func sumFallbackCourierSegmentView(_ view: FallbackCourierSegmentView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedMargin + parsedDosageMg
    }
}
