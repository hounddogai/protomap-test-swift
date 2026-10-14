import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall agreement is in its life cycle.
    enum RecallAgreementStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a recall agreement and its current status.
    final class RecallAgreement {
        var code: String
        var name: String
        var batchSize: Int
        var score: Double
        var checksum: String
        var quantity: Int
        var clinicianID: String
        var createdAt: Int
        var pinned: Bool
        var allergy: String
        var title: String
        var status: RecallAgreementStatus

        init(code: String, name: String, batchSize: Int, score: Double, checksum: String, quantity: Int, clinicianID: String, createdAt: Int, pinned: Bool, allergy: String, title: String, status: RecallAgreementStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.score = score
            self.checksum = checksum
            self.quantity = quantity
            self.clinicianID = clinicianID
            self.createdAt = createdAt
            self.pinned = pinned
            self.allergy = allergy
            self.title = title
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

        func canMoveTo(_ next: RecallAgreementStatus) -> Bool {
            switch status {
            case .created:
                return next == RecallAgreementStatus.validated || next == RecallAgreementStatus.published
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RecallAgreementStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveVolume() -> Double {
            return (Double(batchSize) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> RecallAgreement {
            return RecallAgreement(
                code: code,
                name: name,
                batchSize: batchSize,
                score: score,
                checksum: checksum,
                quantity: quantity,
                clinicianID: clinicianID,
                createdAt: createdAt,
                pinned: pinned,
                allergy: allergy,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a recall agreement in status created.
    static func newRecallAgreement(_ code: String, name: String) -> RecallAgreement {
        return RecallAgreement(
            code: code,
            name: name,
            batchSize: 0,
            score: 0.0,
            checksum: "",
            quantity: 0,
            clinicianID: "",
            createdAt: 0,
            pinned: false,
            allergy: "",
            title: "",
            status: RecallAgreementStatus.created
        )
    }
}
