import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a capped disclosure target.
    final class CappedDisclosureTargetView {
        var code: String
        var title: String
        var wardText: String
        var encounterID: String
        var version: String
        var archivedText: String
        var expiresAtText: String
        var description: String
        var segmentText: String
        var updatedAtText: String
        var statusLabel: String

        init(code: String, title: String, wardText: String, encounterID: String, version: String, archivedText: String, expiresAtText: String, description: String, segmentText: String, updatedAtText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.wardText = wardText
            self.encounterID = encounterID
            self.version = version
            self.archivedText = archivedText
            self.expiresAtText = expiresAtText
            self.description = description
            self.segmentText = segmentText
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedDisclosureTargetView(_ item: CappedDisclosureTarget) -> CappedDisclosureTargetView {
        return CappedDisclosureTargetView(
            code: item.code,
            title: item.title,
            wardText: item.ward,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 64),
            version: String(item.version),
            archivedText: "\(item.archived)",
            expiresAtText: String(item.expiresAt),
            description: Kit.Text.truncate(item.description, limit: 64),
            segmentText: Kit.Text.truncate(item.segment, limit: 80),
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedDisclosureTargetViews(_ items: [CappedDisclosureTarget]) -> [CappedDisclosureTargetView] {
        var views: [CappedDisclosureTargetView] = []
        for item in items {
            views.append(toCappedDisclosureTargetView(item))
        }
        return views
    }

    static func sumCappedDisclosureTargetView(_ view: CappedDisclosureTargetView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedVersion) + Double(parsedExpiresAt) + Double(parsedUpdatedAt)
    }
}
