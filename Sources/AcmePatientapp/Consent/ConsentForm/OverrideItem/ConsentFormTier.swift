import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form tier is in its life cycle.
    enum ConsentFormTierStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A consent form tier. Its code is unique within a tenant.
    final class ConsentFormTier {
        var code: String
        var title: String
        var batchSize: Int
        var bed: String
        var retries: Int
        var visible: Bool
        var clinicianID: String
        var sequence: Int
        var weight: Double
        var graceDays: Int
        var margin: Double
        var status: ConsentFormTierStatus

        init(code: String, title: String, batchSize: Int, bed: String, retries: Int, visible: Bool, clinicianID: String, sequence: Int, weight: Double, graceDays: Int, margin: Double, status: ConsentFormTierStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.bed = bed
            self.retries = retries
            self.visible = visible
            self.clinicianID = clinicianID
            self.sequence = sequence
            self.weight = weight
            self.graceDays = graceDays
            self.margin = margin
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

        func canMoveTo(_ next: ConsentFormTierStatus) -> Bool {
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
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == ConsentFormTierStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("consent form tier") \(code)"
        }

        func adjustedValue() -> Double {
            return (margin * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormTier {
            return ConsentFormTier(
                code: code,
                title: title,
                batchSize: batchSize,
                bed: bed,
                retries: retries,
                visible: visible,
                clinicianID: clinicianID,
                sequence: sequence,
                weight: weight,
                graceDays: graceDays,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a consent form tier in status created.
    static func newConsentFormTier(_ code: String, title: String) -> ConsentFormTier {
        return ConsentFormTier(
            code: code,
            title: title,
            batchSize: 0,
            bed: "",
            retries: 0,
            visible: false,
            clinicianID: "",
            sequence: 0,
            weight: 0.0,
            graceDays: 0,
            margin: 0.0,
            status: ConsentFormTierStatus.created
        )
    }
}
