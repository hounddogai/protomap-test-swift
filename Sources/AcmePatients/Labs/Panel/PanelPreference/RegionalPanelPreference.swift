import AcmePlatform
import Foundation

extension Labs {
    /// Where a regional panel preference is in its life cycle.
    enum RegionalPanelPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a regional panel preference and its current status.
    final class RegionalPanelPreference {
        var code: String
        var label: String
        var endsAt: Int
        var externalRef: String
        var patientRef: String
        var floorValue: Double
        var updatedAt: Int
        var notes: String
        var ceiling: Double
        var quantity: Int
        var checksum: String
        var status: RegionalPanelPreferenceStatus

        init(code: String, label: String, endsAt: Int, externalRef: String, patientRef: String, floorValue: Double, updatedAt: Int, notes: String, ceiling: Double, quantity: Int, checksum: String, status: RegionalPanelPreferenceStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.externalRef = externalRef
            self.patientRef = patientRef
            self.floorValue = floorValue
            self.updatedAt = updatedAt
            self.notes = notes
            self.ceiling = ceiling
            self.quantity = quantity
            self.checksum = checksum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalPanelPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == RegionalPanelPreferenceStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RegionalPanelPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional panel preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedValue() -> Double {
            return ((Double(quantity) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> RegionalPanelPreference {
            return RegionalPanelPreference(
                code: code,
                label: label,
                endsAt: endsAt,
                externalRef: externalRef,
                patientRef: patientRef,
                floorValue: floorValue,
                updatedAt: updatedAt,
                notes: notes,
                ceiling: ceiling,
                quantity: quantity,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional panel preference in status idle.
    static func newRegionalPanelPreference(_ code: String, label: String) -> RegionalPanelPreference {
        return RegionalPanelPreference(
            code: code,
            label: label,
            endsAt: 0,
            externalRef: "",
            patientRef: "",
            floorValue: 0.0,
            updatedAt: 0,
            notes: "",
            ceiling: 0.0,
            quantity: 0,
            checksum: "",
            status: RegionalPanelPreferenceStatus.idle
        )
    }
}
