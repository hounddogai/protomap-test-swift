import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range profile is in its life cycle.
    enum ReferenceRangeProfileStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A reference range profile as the reference range team keeps it.
    final class ReferenceRangeProfile {
        var code: String
        var name: String
        var payer: String
        var segment: String
        var margin: Double
        var createdAt: Int
        var patientRef: String
        var minimum: Double
        var limit: Int
        var status: ReferenceRangeProfileStatus

        init(code: String, name: String, payer: String, segment: String, margin: Double, createdAt: Int, patientRef: String, minimum: Double, limit: Int, status: ReferenceRangeProfileStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.segment = segment
            self.margin = margin
            self.createdAt = createdAt
            self.patientRef = patientRef
            self.minimum = minimum
            self.limit = limit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferenceRangeProfileStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ReferenceRangeProfileStatus.published || next == ReferenceRangeProfileStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ReferenceRangeProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedExposure() -> Double {
            return ((minimum + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeProfile {
            return ReferenceRangeProfile(
                code: code,
                name: name,
                payer: payer,
                segment: segment,
                margin: margin,
                createdAt: createdAt,
                patientRef: patientRef,
                minimum: minimum,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a reference range profile in status created.
    static func newReferenceRangeProfile(_ code: String, name: String) -> ReferenceRangeProfile {
        return ReferenceRangeProfile(
            code: code,
            name: name,
            payer: "",
            segment: "",
            margin: 0.0,
            createdAt: 0,
            patientRef: "",
            minimum: 0.0,
            limit: 0,
            status: ReferenceRangeProfileStatus.created
        )
    }
}
