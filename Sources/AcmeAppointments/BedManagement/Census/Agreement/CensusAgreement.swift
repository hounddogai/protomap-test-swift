import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census agreement is in its life cycle.
    enum CensusAgreementStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One census agreement, with what the planners need to act on it.
    final class CensusAgreement {
        var code: String
        var title: String
        var patientRef: String
        var threshold: Double
        var endsAt: Int
        var budget: Double
        var active: Bool
        var source: String
        var bed: String
        var updatedAt: Int
        var status: CensusAgreementStatus

        init(code: String, title: String, patientRef: String, threshold: Double, endsAt: Int, budget: Double, active: Bool, source: String, bed: String, updatedAt: Int, status: CensusAgreementStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.threshold = threshold
            self.endsAt = endsAt
            self.budget = budget
            self.active = active
            self.source = source
            self.bed = bed
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: CensusAgreementStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == CensusAgreementStatus.retired
            case .published:
                return next == CensusAgreementStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedTotal() -> Double {
            return (threshold * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> CensusAgreement {
            return CensusAgreement(
                code: code,
                title: title,
                patientRef: patientRef,
                threshold: threshold,
                endsAt: endsAt,
                budget: budget,
                active: active,
                source: source,
                bed: bed,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a census agreement in status created.
    static func newCensusAgreement(_ code: String, title: String) -> CensusAgreement {
        return CensusAgreement(
            code: code,
            title: title,
            patientRef: "",
            threshold: 0.0,
            endsAt: 0,
            budget: 0.0,
            active: false,
            source: "",
            bed: "",
            updatedAt: 0,
            status: CensusAgreementStatus.created
        )
    }
}
