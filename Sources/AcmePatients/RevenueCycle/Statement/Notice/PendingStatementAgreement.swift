import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending statement agreement is in its life cycle.
    enum PendingStatementAgreementStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a pending statement agreement and its current status.
    final class PendingStatementAgreement {
        var code: String
        var name: String
        var ratio: Double
        var specialty: String
        var region: String
        var checksum: String
        var revision: Int
        var limit: Int
        var copay: Double
        var unit: String
        var status: PendingStatementAgreementStatus

        init(code: String, name: String, ratio: Double, specialty: String, region: String, checksum: String, revision: Int, limit: Int, copay: Double, unit: String, status: PendingStatementAgreementStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.specialty = specialty
            self.region = region
            self.checksum = checksum
            self.revision = revision
            self.limit = limit
            self.copay = copay
            self.unit = unit
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

        func canMoveTo(_ next: PendingStatementAgreementStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == PendingStatementAgreementStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingStatementAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending statement agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedLoad() -> Double {
            return ((ratio + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> PendingStatementAgreement {
            return PendingStatementAgreement(
                code: code,
                name: name,
                ratio: ratio,
                specialty: specialty,
                region: region,
                checksum: checksum,
                revision: revision,
                limit: limit,
                copay: copay,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a pending statement agreement in status created.
    static func newPendingStatementAgreement(_ code: String, name: String) -> PendingStatementAgreement {
        return PendingStatementAgreement(
            code: code,
            name: name,
            ratio: 0.0,
            specialty: "",
            region: "",
            checksum: "",
            revision: 0,
            limit: 0,
            copay: 0.0,
            unit: "",
            status: PendingStatementAgreementStatus.created
        )
    }
}
