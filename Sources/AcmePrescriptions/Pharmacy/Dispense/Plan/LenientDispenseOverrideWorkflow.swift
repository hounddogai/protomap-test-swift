import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves lenient dispense overrides through their life cycle and keeps a journal of what it did.
    final class LenientDispenseOverrideService {
        var store: any LenientDispenseOverrideStore
        var validator: LenientDispenseOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientDispenseOverrideEngine

        init(store: any LenientDispenseOverrideStore, validator: LenientDispenseOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientDispenseOverrideEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient dispense override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientDispenseOverrideStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient dispense override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientDispenseOverrideStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient dispense override \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newLenientDispenseOverrideService(_ store: any LenientDispenseOverrideStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientDispenseOverrideService {
        return LenientDispenseOverrideService(
            store: store,
            validator: defaultLenientDispenseOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientDispenseOverrideEngine(flags)
        )
    }
}
