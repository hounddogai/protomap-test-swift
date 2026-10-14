import AcmePlatform
import Foundation

extension Consent {
    /// Moves lenient revocation variances through their life cycle and keeps a journal of what it did.
    final class LenientRevocationVarianceService {
        var store: any LenientRevocationVarianceStore
        var validator: LenientRevocationVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientRevocationVarianceEngine

        init(store: any LenientRevocationVarianceStore, validator: LenientRevocationVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientRevocationVarianceEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient revocation variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientRevocationVarianceStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient revocation variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientRevocationVarianceStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient revocation variance \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newLenientRevocationVarianceService(_ store: any LenientRevocationVarianceStore, clock: any Kit.Clocks.Clock) -> LenientRevocationVarianceService {
        return LenientRevocationVarianceService(
            store: store,
            validator: defaultLenientRevocationVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientRevocationVarianceEngine()
        )
    }
}
