import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol template.
    final class CareProtocolTemplateView {
        var code: String
        var name: String
        var archived: String
        var version: String
        var checksumText: String
        var statusLabel: String

        init(code: String, name: String, archived: String, version: String, checksumText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.archived = archived
            self.version = version
            self.checksumText = checksumText
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolTemplateView(_ item: CareProtocolTemplate) -> CareProtocolTemplateView {
        return CareProtocolTemplateView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            archived: "\(item.archived)",
            version: String(item.version),
            checksumText: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolTemplateViews(_ items: [CareProtocolTemplate]) -> [CareProtocolTemplateView] {
        var views: [CareProtocolTemplateView] = []
        for item in items {
            views.append(toCareProtocolTemplateView(item))
        }
        return views
    }

    static func sumCareProtocolTemplateView(_ view: CareProtocolTemplateView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedVersion)
    }
}
