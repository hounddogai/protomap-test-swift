import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge proposal.
    final class ChargeProposalView {
        var codeText: String
        var nameText: String
        var visibleText: String
        var segment: String
        var version: String
        var ceiling: String
        var checksumText: String
        var channel: String
        var specialty: String
        var quantity: String
        var rateText: String
        var statusLabel: String

        init(codeText: String, nameText: String, visibleText: String, segment: String, version: String, ceiling: String, checksumText: String, channel: String, specialty: String, quantity: String, rateText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.visibleText = visibleText
            self.segment = segment
            self.version = version
            self.ceiling = ceiling
            self.checksumText = checksumText
            self.channel = channel
            self.specialty = specialty
            self.quantity = quantity
            self.rateText = rateText
            self.statusLabel = statusLabel
        }
    }

    static func toChargeProposalView(_ item: ChargeProposal) -> ChargeProposalView {
        return ChargeProposalView(
            codeText: item.code,
            nameText: item.name,
            visibleText: "\(item.visible)",
            segment: Kit.Text.truncate(item.segment, limit: 120),
            version: String(item.version),
            ceiling: String(format: "%.2f", item.ceiling),
            checksumText: Kit.Text.truncate(item.checksum, limit: 80),
            channel: item.channel,
            specialty: Kit.Text.truncate(item.specialty, limit: 120),
            quantity: String(item.quantity),
            rateText: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeProposalViews(_ items: [ChargeProposal]) -> [ChargeProposalView] {
        var views: [ChargeProposalView] = []
        for item in items {
            views.append(toChargeProposalView(item))
        }
        return views
    }

    static func sumChargeProposalView(_ view: ChargeProposalView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedVersion) + parsedCeiling + Double(parsedQuantity)
    }
}
