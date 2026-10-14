import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range segment.
    final class ReferenceRangeSegmentView {
        var code: String
        var nameText: String
        var specialty: String
        var retriesText: String
        var acuityText: String
        var segment: String
        var visitMinutes: String
        var active: String
        var statusLabel: String

        init(code: String, nameText: String, specialty: String, retriesText: String, acuityText: String, segment: String, visitMinutes: String, active: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.specialty = specialty
            self.retriesText = retriesText
            self.acuityText = acuityText
            self.segment = segment
            self.visitMinutes = visitMinutes
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeSegmentView(_ item: ReferenceRangeSegment) -> ReferenceRangeSegmentView {
        return ReferenceRangeSegmentView(
            code: item.code,
            nameText: item.name,
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            retriesText: String(item.retries),
            acuityText: String(item.acuity),
            segment: item.segment,
            visitMinutes: String(item.visitMinutes),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeSegmentViews(_ items: [ReferenceRangeSegment]) -> [ReferenceRangeSegmentView] {
        var views: [ReferenceRangeSegmentView] = []
        for item in items {
            views.append(toReferenceRangeSegmentView(item))
        }
        return views
    }

    static func sumReferenceRangeSegmentView(_ view: ReferenceRangeSegmentView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedRetries) + Double(parsedAcuity) + Double(parsedVisitMinutes)
    }
}
