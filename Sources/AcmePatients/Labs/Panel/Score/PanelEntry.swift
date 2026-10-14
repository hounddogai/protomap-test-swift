import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel entry is in its life cycle.
    enum PanelEntryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a panel entry and its current status.
    final class PanelEntry {
        var code: String
        var name: String
        var externalRef: String
        var batchSize: Int
        var source: String
        var createdAt: Int
        var country: String
        var ownerID: String
        var currency: String
        var allergy: String
        var durationMinutes: Int
        var status: PanelEntryStatus

        init(code: String, name: String, externalRef: String, batchSize: Int, source: String, createdAt: Int, country: String, ownerID: String, currency: String, allergy: String, durationMinutes: Int, status: PanelEntryStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.batchSize = batchSize
            self.source = source
            self.createdAt = createdAt
            self.country = country
            self.ownerID = ownerID
            self.currency = currency
            self.allergy = allergy
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PanelEntryStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == PanelEntryStatus.inProgress || next == PanelEntryStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedExposure() -> Double {
            return (Double(durationMinutes) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> PanelEntry {
            return PanelEntry(
                code: code,
                name: name,
                externalRef: externalRef,
                batchSize: batchSize,
                source: source,
                createdAt: createdAt,
                country: country,
                ownerID: ownerID,
                currency: currency,
                allergy: allergy,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a panel entry in status planned.
    static func newPanelEntry(_ code: String, name: String) -> PanelEntry {
        return PanelEntry(
            code: code,
            name: name,
            externalRef: "",
            batchSize: 0,
            source: "",
            createdAt: 0,
            country: "",
            ownerID: "",
            currency: "",
            allergy: "",
            durationMinutes: 0,
            status: PanelEntryStatus.planned
        )
    }
}
