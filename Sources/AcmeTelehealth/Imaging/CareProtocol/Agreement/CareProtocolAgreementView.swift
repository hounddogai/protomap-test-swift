import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol agreement.
    final class CareProtocolAgreementView {
        var code: String
        var title: String
        var bedText: String
        var ratio: String
        var pinnedText: String
        var cost: String
        var wardText: String
        var capacity: String
        var updatedAt: String
        var externalRef: String
        var statusLabel: String

        init(code: String, title: String, bedText: String, ratio: String, pinnedText: String, cost: String, wardText: String, capacity: String, updatedAt: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.bedText = bedText
            self.ratio = ratio
            self.pinnedText = pinnedText
            self.cost = cost
            self.wardText = wardText
            self.capacity = capacity
            self.updatedAt = updatedAt
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolAgreementView(_ item: CareProtocolAgreement) -> CareProtocolAgreementView {
        return CareProtocolAgreementView(
            code: item.code,
            title: item.title,
            bedText: item.bed,
            ratio: String(format: "%.2f", item.ratio),
            pinnedText: "\(item.pinned)",
            cost: String(format: "%.2f", item.cost),
            wardText: item.ward,
            capacity: String(item.capacity),
            updatedAt: String(item.updatedAt),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolAgreementViews(_ items: [CareProtocolAgreement]) -> [CareProtocolAgreementView] {
        var views: [CareProtocolAgreementView] = []
        for item in items {
            views.append(toCareProtocolAgreementView(item))
        }
        return views
    }

    static func sumCareProtocolAgreementView(_ view: CareProtocolAgreementView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedRatio + parsedCost + Double(parsedCapacity)
    }
}
