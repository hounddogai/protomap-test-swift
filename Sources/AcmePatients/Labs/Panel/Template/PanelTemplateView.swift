import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel template.
    final class PanelTemplateView {
        var codeText: String
        var nameText: String
        var externalRef: String
        var updatedAtText: String
        var facility: String
        var minimum: String
        var region: String
        var title: String
        var acuity: String
        var floorValue: String
        var statusLabel: String

        init(codeText: String, nameText: String, externalRef: String, updatedAtText: String, facility: String, minimum: String, region: String, title: String, acuity: String, floorValue: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.externalRef = externalRef
            self.updatedAtText = updatedAtText
            self.facility = facility
            self.minimum = minimum
            self.region = region
            self.title = title
            self.acuity = acuity
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toPanelTemplateView(_ item: PanelTemplate) -> PanelTemplateView {
        return PanelTemplateView(
            codeText: item.code,
            nameText: item.name,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            updatedAtText: String(item.updatedAt),
            facility: item.facility,
            minimum: String(format: "%.2f", item.minimum),
            region: item.region,
            title: item.title,
            acuity: String(item.acuity),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelTemplateViews(_ items: [PanelTemplate]) -> [PanelTemplateView] {
        var views: [PanelTemplateView] = []
        for item in items {
            views.append(toPanelTemplateView(item))
        }
        return views
    }

    static func sumPanelTemplateView(_ view: PanelTemplateView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedUpdatedAt) + parsedMinimum + Double(parsedAcuity)
    }
}
