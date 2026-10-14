import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a global handoff quota.
    final class GlobalHandoffQuotaView {
        var code: String
        var title: String
        var diagnosisCodeText: String
        var encounterIDText: String
        var archivedText: String
        var priority: String
        var pinned: String
        var country: String
        var createdAtText: String
        var statusLabel: String

        init(code: String, title: String, diagnosisCodeText: String, encounterIDText: String, archivedText: String, priority: String, pinned: String, country: String, createdAtText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.diagnosisCodeText = diagnosisCodeText
            self.encounterIDText = encounterIDText
            self.archivedText = archivedText
            self.priority = priority
            self.pinned = pinned
            self.country = country
            self.createdAtText = createdAtText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalHandoffQuotaView(_ item: GlobalHandoffQuota) -> GlobalHandoffQuotaView {
        return GlobalHandoffQuotaView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            diagnosisCodeText: item.diagnosisCode,
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 120),
            archivedText: "\(item.archived)",
            priority: String(item.priority),
            pinned: "\(item.pinned)",
            country: Kit.Text.truncate(item.country, limit: 40),
            createdAtText: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalHandoffQuotaViews(_ items: [GlobalHandoffQuota]) -> [GlobalHandoffQuotaView] {
        var views: [GlobalHandoffQuotaView] = []
        for item in items {
            views.append(toGlobalHandoffQuotaView(item))
        }
        return views
    }

    static func sumGlobalHandoffQuotaView(_ view: GlobalHandoffQuotaView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedPriority) + Double(parsedCreatedAt)
    }
}
