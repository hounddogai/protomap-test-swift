import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves lenient inventory overrides through their life cycle and keeps a journal of what it did.
    final class LenientInventoryOverrideService {
        var store: any LenientInventoryOverrideStore
        var validator: LenientInventoryOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientInventoryOverrideEngine

        init(store: any LenientInventoryOverrideStore, validator: LenientInventoryOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientInventoryOverrideEngine) {
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
                throw Kit.Failure("lenient inventory override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientInventoryOverrideStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient inventory override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientInventoryOverrideStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient inventory override \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newLenientInventoryOverrideService(_ store: any LenientInventoryOverrideStore, clock: any Kit.Clocks.Clock) -> LenientInventoryOverrideService {
        return LenientInventoryOverrideService(
            store: store,
            validator: defaultLenientInventoryOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientInventoryOverrideEngine()
        )
    }
}
