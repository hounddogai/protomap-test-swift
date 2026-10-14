import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient dispense bundle is in its life cycle.
    enum LenientDispenseBundleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a lenient dispense bundle and its current status.
    final class LenientDispenseBundle {
        var code: String
        var name: String
        var discount: Double
        var title: String
        var version: Int
        var country: String
        var attributes: [String: String]
        var ward: String
        var status: LenientDispenseBundleStatus

        init(code: String, name: String, discount: Double, title: String, version: Int, country: String, attributes: [String: String], ward: String, status: LenientDispenseBundleStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.title = title
            self.version = version
            self.country = country
            self.attributes = attributes
            self.ward = ward
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientDispenseBundleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == LenientDispenseBundleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientDispenseBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient dispense bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
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

        func projectedExposure() -> Double {
            return (discount * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> LenientDispenseBundle {
            return LenientDispenseBundle(
                code: code,
                name: name,
                discount: discount,
                title: title,
                version: version,
                country: country,
                attributes: attributes,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a lenient dispense bundle in status planned.
    static func newLenientDispenseBundle(_ code: String, name: String) -> LenientDispenseBundle {
        return LenientDispenseBundle(
            code: code,
            name: name,
            discount: 0.0,
            title: "",
            version: 0,
            country: "",
            attributes: [:],
            ward: "",
            status: LenientDispenseBundleStatus.planned
        )
    }
}
