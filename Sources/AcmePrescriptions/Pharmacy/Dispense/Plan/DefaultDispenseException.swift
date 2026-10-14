import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default dispense exception is in its life cycle.
    enum DefaultDispenseExceptionStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One default dispense exception, with what the planners need to act on it.
    final class DefaultDispenseException {
        var code: String
        var name: String
        var visible: Bool
        var amount: Double
        var weight: Double
        var tags: [String]
        var locale: String
        var bed: String
        var status: DefaultDispenseExceptionStatus

        init(code: String, name: String, visible: Bool, amount: Double, weight: Double, tags: [String], locale: String, bed: String, status: DefaultDispenseExceptionStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.amount = amount
            self.weight = weight
            self.tags = tags
            self.locale = locale
            self.bed = bed
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

        func canMoveTo(_ next: DefaultDispenseExceptionStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
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

        func moveTo(_ next: DefaultDispenseExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default dispense exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedVolume() -> Double {
            return (weight * amount * 100).rounded() / 100
        }

        func copyValue() -> DefaultDispenseException {
            return DefaultDispenseException(
                code: code,
                name: name,
                visible: visible,
                amount: amount,
                weight: weight,
                tags: tags,
                locale: locale,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a default dispense exception in status created.
    static func newDefaultDispenseException(_ code: String, name: String) -> DefaultDispenseException {
        return DefaultDispenseException(
            code: code,
            name: name,
            visible: false,
            amount: 0.0,
            weight: 0.0,
            tags: [],
            locale: "",
            bed: "",
            status: DefaultDispenseExceptionStatus.created
        )
    }
}
