import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense tier is in its life cycle.
    enum DispenseTierStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A dispense tier. Its code is unique within a tenant.
    final class DispenseTier {
        var code: String
        var name: String
        var sequence: Int
        var country: String
        var ratio: Double
        var clinicianID: String
        var facility: String
        var status: DispenseTierStatus

        init(code: String, name: String, sequence: Int, country: String, ratio: Double, clinicianID: String, facility: String, status: DispenseTierStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.country = country
            self.ratio = ratio
            self.clinicianID = clinicianID
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DispenseTierStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == DispenseTierStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveValue() -> Double {
            return (ratio * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> DispenseTier {
            return DispenseTier(
                code: code,
                name: name,
                sequence: sequence,
                country: country,
                ratio: ratio,
                clinicianID: clinicianID,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a dispense tier in status open.
    static func newDispenseTier(_ code: String, name: String) -> DispenseTier {
        return DispenseTier(
            code: code,
            name: name,
            sequence: 0,
            country: "",
            ratio: 0.0,
            clinicianID: "",
            facility: "",
            status: DispenseTierStatus.`open`
        )
    }
}
