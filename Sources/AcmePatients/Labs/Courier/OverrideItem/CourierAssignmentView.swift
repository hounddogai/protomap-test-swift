import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier assignment.
    final class CourierAssignmentView {
        var codeText: String
        var name: String
        var locale: String
        var checksum: String
        var externalRefText: String
        var pinned: String
        var title: String
        var scoreText: String
        var statusLabel: String

        init(codeText: String, name: String, locale: String, checksum: String, externalRefText: String, pinned: String, title: String, scoreText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.locale = locale
            self.checksum = checksum
            self.externalRefText = externalRefText
            self.pinned = pinned
            self.title = title
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toCourierAssignmentView(_ item: CourierAssignment) -> CourierAssignmentView {
        return CourierAssignmentView(
            codeText: item.code,
            name: item.name,
            locale: item.locale,
            checksum: item.checksum,
            externalRefText: Kit.Text.truncate(item.externalRef, limit: 80),
            pinned: "\(item.pinned)",
            title: item.title,
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierAssignmentViews(_ items: [CourierAssignment]) -> [CourierAssignmentView] {
        var views: [CourierAssignmentView] = []
        for item in items {
            views.append(toCourierAssignmentView(item))
        }
        return views
    }

    static func sumCourierAssignmentView(_ view: CourierAssignmentView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
