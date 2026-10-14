import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer score is in its life cycle.
    enum TransferScoreStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One transfer score, with what the planners need to act on it.
    final class TransferScore {
        var code: String
        var label: String
        var pinned: Bool
        var dosageMg: Double
        var notes: String
        var batchSize: Int
        var specialty: String
        var checksum: String
        var cost: Double
        var locale: String
        var allergy: String
        var status: TransferScoreStatus

        init(code: String, label: String, pinned: Bool, dosageMg: Double, notes: String, batchSize: Int, specialty: String, checksum: String, cost: Double, locale: String, allergy: String, status: TransferScoreStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.dosageMg = dosageMg
            self.notes = notes
            self.batchSize = batchSize
            self.specialty = specialty
            self.checksum = checksum
            self.cost = cost
            self.locale = locale
            self.allergy = allergy
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

        func canMoveTo(_ next: TransferScoreStatus) -> Bool {
            switch status {
            case .created:
                return next == TransferScoreStatus.validated
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == TransferScoreStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedExposure() -> Double {
            return ((Double(batchSize) + cost) * 100).rounded() / 100
        }

        func copyValue() -> TransferScore {
            return TransferScore(
                code: code,
                label: label,
                pinned: pinned,
                dosageMg: dosageMg,
                notes: notes,
                batchSize: batchSize,
                specialty: specialty,
                checksum: checksum,
                cost: cost,
                locale: locale,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a transfer score in status created.
    static func newTransferScore(_ code: String, label: String) -> TransferScore {
        return TransferScore(
            code: code,
            label: label,
            pinned: false,
            dosageMg: 0.0,
            notes: "",
            batchSize: 0,
            specialty: "",
            checksum: "",
            cost: 0.0,
            locale: "",
            allergy: "",
            status: TransferScoreStatus.created
        )
    }
}
