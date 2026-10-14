import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol entry.
    final class CareProtocolEntryView {
        var codeText: String
        var name: String
        var acuity: String
        var wardText: String
        var notesText: String
        var approvedText: String
        var statusLabel: String

        init(codeText: String, name: String, acuity: String, wardText: String, notesText: String, approvedText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.acuity = acuity
            self.wardText = wardText
            self.notesText = notesText
            self.approvedText = approvedText
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolEntryView(_ item: CareProtocolEntry) -> CareProtocolEntryView {
        return CareProtocolEntryView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            acuity: String(item.acuity),
            wardText: Kit.Text.truncate(item.ward, limit: 120),
            notesText: item.notes,
            approvedText: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolEntryViews(_ items: [CareProtocolEntry]) -> [CareProtocolEntryView] {
        var views: [CareProtocolEntryView] = []
        for item in items {
            views.append(toCareProtocolEntryView(item))
        }
        return views
    }

    static func sumCareProtocolEntryView(_ view: CareProtocolEntryView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedAcuity)
    }
}
