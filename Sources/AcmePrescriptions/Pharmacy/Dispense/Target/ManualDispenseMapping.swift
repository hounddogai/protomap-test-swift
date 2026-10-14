import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual dispense mapping is in its life cycle.
    enum ManualDispenseMappingStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a manual dispense mapping and its current status.
    final class ManualDispenseMapping {
        var code: String
        var label: String
        var ward: String
        var region: String
        var attempts: Int
        var summary: String
        var description: String
        var active: Bool
        var clinicianID: String
        var budget: Double
        var visible: Bool
        var status: ManualDispenseMappingStatus

        init(code: String, label: String, ward: String, region: String, attempts: Int, summary: String, description: String, active: Bool, clinicianID: String, budget: Double, visible: Bool, status: ManualDispenseMappingStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.region = region
            self.attempts = attempts
            self.summary = summary
            self.description = description
            self.active = active
            self.clinicianID = clinicianID
            self.budget = budget
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualDispenseMappingStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ManualDispenseMappingStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualDispenseMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual dispense mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netTotal() -> Double {
            return (Double(attempts) * budget * 100).rounded() / 100
        }

        func copyValue() -> ManualDispenseMapping {
            return ManualDispenseMapping(
                code: code,
                label: label,
                ward: ward,
                region: region,
                attempts: attempts,
                summary: summary,
                description: description,
                active: active,
                clinicianID: clinicianID,
                budget: budget,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a manual dispense mapping in status new.
    static func newManualDispenseMapping(_ code: String, label: String) -> ManualDispenseMapping {
        return ManualDispenseMapping(
            code: code,
            label: label,
            ward: "",
            region: "",
            attempts: 0,
            summary: "",
            description: "",
            active: false,
            clinicianID: "",
            budget: 0.0,
            visible: false,
            status: ManualDispenseMappingStatus.new
        )
    }
}
