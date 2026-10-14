import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a capped modality assignment.
    final class CappedModalityAssignmentView {
        var codeText: String
        var title: String
        var score: String
        var startsAt: String
        var payer: String
        var checksum: String
        var ward: String
        var windowDays: String
        var maximum: String
        var specialty: String
        var statusLabel: String

        init(codeText: String, title: String, score: String, startsAt: String, payer: String, checksum: String, ward: String, windowDays: String, maximum: String, specialty: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.score = score
            self.startsAt = startsAt
            self.payer = payer
            self.checksum = checksum
            self.ward = ward
            self.windowDays = windowDays
            self.maximum = maximum
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toCappedModalityAssignmentView(_ item: CappedModalityAssignment) -> CappedModalityAssignmentView {
        return CappedModalityAssignmentView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            score: String(format: "%.2f", item.score),
            startsAt: String(item.startsAt),
            payer: item.payer,
            checksum: item.checksum,
            ward: item.ward,
            windowDays: String(item.windowDays),
            maximum: String(format: "%.2f", item.maximum),
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedModalityAssignmentViews(_ items: [CappedModalityAssignment]) -> [CappedModalityAssignmentView] {
        var views: [CappedModalityAssignmentView] = []
        for item in items {
            views.append(toCappedModalityAssignmentView(item))
        }
        return views
    }

    static func sumCappedModalityAssignmentView(_ view: CappedModalityAssignmentView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedScore + Double(parsedStartsAt) + Double(parsedWindowDays)
    }
}
