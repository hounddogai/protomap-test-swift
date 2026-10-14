import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a primary census proposal.
    final class PrimaryCensusProposalView {
        var code: String
        var titleText: String
        var windowDays: String
        var patientRefText: String
        var capacityText: String
        var pinned: String
        var ownerIDText: String
        var segmentText: String
        var category: String
        var version: String
        var limitText: String
        var statusLabel: String

        init(code: String, titleText: String, windowDays: String, patientRefText: String, capacityText: String, pinned: String, ownerIDText: String, segmentText: String, category: String, version: String, limitText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.windowDays = windowDays
            self.patientRefText = patientRefText
            self.capacityText = capacityText
            self.pinned = pinned
            self.ownerIDText = ownerIDText
            self.segmentText = segmentText
            self.category = category
            self.version = version
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryCensusProposalView(_ item: PrimaryCensusProposal) -> PrimaryCensusProposalView {
        return PrimaryCensusProposalView(
            code: item.code,
            titleText: item.title,
            windowDays: String(item.windowDays),
            patientRefText: item.patientRef,
            capacityText: String(item.capacity),
            pinned: "\(item.pinned)",
            ownerIDText: item.ownerID,
            segmentText: Kit.Text.truncate(item.segment, limit: 40),
            category: item.category,
            version: String(item.version),
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryCensusProposalViews(_ items: [PrimaryCensusProposal]) -> [PrimaryCensusProposalView] {
        var views: [PrimaryCensusProposalView] = []
        for item in items {
            views.append(toPrimaryCensusProposalView(item))
        }
        return views
    }

    static func sumPrimaryCensusProposalView(_ view: PrimaryCensusProposalView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedCapacity) + Double(parsedVersion)
    }
}
