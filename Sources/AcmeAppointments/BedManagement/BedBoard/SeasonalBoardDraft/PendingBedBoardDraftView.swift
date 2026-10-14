import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a pending bed board draft.
    final class PendingBedBoardDraftView {
        var codeText: String
        var name: String
        var segment: String
        var capacity: String
        var amount: String
        var ward: String
        var costText: String
        var endsAt: String
        var startsAt: String
        var batchSize: String
        var procedureCode: String
        var statusLabel: String

        init(codeText: String, name: String, segment: String, capacity: String, amount: String, ward: String, costText: String, endsAt: String, startsAt: String, batchSize: String, procedureCode: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.segment = segment
            self.capacity = capacity
            self.amount = amount
            self.ward = ward
            self.costText = costText
            self.endsAt = endsAt
            self.startsAt = startsAt
            self.batchSize = batchSize
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toPendingBedBoardDraftView(_ item: PendingBedBoardDraft) -> PendingBedBoardDraftView {
        return PendingBedBoardDraftView(
            codeText: item.code,
            name: item.name,
            segment: Kit.Text.truncate(item.segment, limit: 40),
            capacity: String(item.capacity),
            amount: String(format: "%.2f", item.amount),
            ward: item.ward,
            costText: String(format: "%.2f", item.cost),
            endsAt: String(item.endsAt),
            startsAt: String(item.startsAt),
            batchSize: String(item.batchSize),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingBedBoardDraftViews(_ items: [PendingBedBoardDraft]) -> [PendingBedBoardDraftView] {
        var views: [PendingBedBoardDraftView] = []
        for item in items {
            views.append(toPendingBedBoardDraftView(item))
        }
        return views
    }

    static func sumPendingBedBoardDraftView(_ view: PendingBedBoardDraftView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedCapacity) + parsedAmount + parsedCost
    }
}
