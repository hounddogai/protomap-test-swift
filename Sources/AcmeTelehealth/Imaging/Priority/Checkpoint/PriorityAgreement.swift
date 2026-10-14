import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority agreement is in its life cycle.
    enum PriorityAgreementStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A priority agreement. Its code is unique within a tenant.
    final class PriorityAgreement {
        var code: String
        var name: String
        var notes: String
        var specialty: String
        var attributes: [String: String]
        var priority: Int
        var externalRef: String
        var allergy: String
        var amount: Double
        var category: String
        var status: PriorityAgreementStatus

        init(code: String, name: String, notes: String, specialty: String, attributes: [String: String], priority: Int, externalRef: String, allergy: String, amount: Double, category: String, status: PriorityAgreementStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.specialty = specialty
            self.attributes = attributes
            self.priority = priority
            self.externalRef = externalRef
            self.allergy = allergy
            self.amount = amount
            self.category = category
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

        func canMoveTo(_ next: PriorityAgreementStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == PriorityAgreementStatus.archived
            case .resolved:
                return next == PriorityAgreementStatus.reopened || next == PriorityAgreementStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: PriorityAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedValue() -> Double {
            return ((amount - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> PriorityAgreement {
            return PriorityAgreement(
                code: code,
                name: name,
                notes: notes,
                specialty: specialty,
                attributes: attributes,
                priority: priority,
                externalRef: externalRef,
                allergy: allergy,
                amount: amount,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a priority agreement in status open.
    static func newPriorityAgreement(_ code: String, name: String) -> PriorityAgreement {
        return PriorityAgreement(
            code: code,
            name: name,
            notes: "",
            specialty: "",
            attributes: [:],
            priority: 0,
            externalRef: "",
            allergy: "",
            amount: 0.0,
            category: "",
            status: PriorityAgreementStatus.`open`
        )
    }
}
