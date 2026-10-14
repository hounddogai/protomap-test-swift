import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program summary.
    final class ProgramSummaryView {
        var codeText: String
        var title: String
        var maximum: String
        var checksum: String
        var version: String
        var visible: String
        var createdAt: String
        var expiresAt: String
        var minimum: String
        var descriptionText: String
        var statusLabel: String

        init(codeText: String, title: String, maximum: String, checksum: String, version: String, visible: String, createdAt: String, expiresAt: String, minimum: String, descriptionText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.maximum = maximum
            self.checksum = checksum
            self.version = version
            self.visible = visible
            self.createdAt = createdAt
            self.expiresAt = expiresAt
            self.minimum = minimum
            self.descriptionText = descriptionText
            self.statusLabel = statusLabel
        }
    }

    static func toProgramSummaryView(_ item: ProgramSummary) -> ProgramSummaryView {
        return ProgramSummaryView(
            codeText: item.code,
            title: item.title,
            maximum: String(format: "%.2f", item.maximum),
            checksum: item.checksum,
            version: String(item.version),
            visible: "\(item.visible)",
            createdAt: String(item.createdAt),
            expiresAt: String(item.expiresAt),
            minimum: String(format: "%.2f", item.minimum),
            descriptionText: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramSummaryViews(_ items: [ProgramSummary]) -> [ProgramSummaryView] {
        var views: [ProgramSummaryView] = []
        for item in items {
            views.append(toProgramSummaryView(item))
        }
        return views
    }

    static func sumProgramSummaryView(_ view: ProgramSummaryView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedMaximum + Double(parsedVersion) + Double(parsedCreatedAt)
    }
}
