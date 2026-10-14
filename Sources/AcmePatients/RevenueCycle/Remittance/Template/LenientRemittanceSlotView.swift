import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a lenient remittance slot.
    final class LenientRemittanceSlotView {
        var code: String
        var title: String
        var region: String
        var segment: String
        var version: String
        var statusLabel: String

        init(code: String, title: String, region: String, segment: String, version: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.region = region
            self.segment = segment
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toLenientRemittanceSlotView(_ item: LenientRemittanceSlot) -> LenientRemittanceSlotView {
        return LenientRemittanceSlotView(
            code: item.code,
            title: item.title,
            region: item.region,
            segment: item.segment,
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientRemittanceSlotViews(_ items: [LenientRemittanceSlot]) -> [LenientRemittanceSlotView] {
        var views: [LenientRemittanceSlotView] = []
        for item in items {
            views.append(toLenientRemittanceSlotView(item))
        }
        return views
    }

    static func sumLenientRemittanceSlotView(_ view: LenientRemittanceSlotView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedVersion)
    }
}
