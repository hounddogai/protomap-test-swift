import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier draft.
    final class CourierDraftView {
        var code: String
        var nameText: String
        var maximumText: String
        var country: String
        var unit: String
        var startsAtText: String
        var weightText: String
        var notes: String
        var channel: String
        var specialty: String
        var statusLabel: String

        init(code: String, nameText: String, maximumText: String, country: String, unit: String, startsAtText: String, weightText: String, notes: String, channel: String, specialty: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.maximumText = maximumText
            self.country = country
            self.unit = unit
            self.startsAtText = startsAtText
            self.weightText = weightText
            self.notes = notes
            self.channel = channel
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toCourierDraftView(_ item: CourierDraft) -> CourierDraftView {
        return CourierDraftView(
            code: item.code,
            nameText: item.name,
            maximumText: String(format: "%.2f", item.maximum),
            country: item.country,
            unit: Kit.Text.truncate(item.unit, limit: 64),
            startsAtText: String(item.startsAt),
            weightText: String(format: "%.2f", item.weight),
            notes: item.notes,
            channel: item.channel,
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierDraftViews(_ items: [CourierDraft]) -> [CourierDraftView] {
        var views: [CourierDraftView] = []
        for item in items {
            views.append(toCourierDraftView(item))
        }
        return views
    }

    static func sumCourierDraftView(_ view: CourierDraftView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedMaximum + Double(parsedStartsAt) + parsedWeight
    }
}
