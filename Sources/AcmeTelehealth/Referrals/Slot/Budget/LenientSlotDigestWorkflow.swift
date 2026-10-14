import AcmePlatform
import Foundation

extension Referrals {
    /// Moves lenient slot digests through their life cycle and keeps a journal of what it did.
    final class LenientSlotDigestDesk {
        var store: any LenientSlotDigestStore
        var validator: LenientSlotDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientSlotDigestEngine

        init(store: any LenientSlotDigestStore, validator: LenientSlotDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientSlotDigestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient slot digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientSlotDigestStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient slot digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientSlotDigestStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient slot digest \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newLenientSlotDigestDesk(_ store: any LenientSlotDigestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientSlotDigestDesk {
        return LenientSlotDigestDesk(
            store: store,
            validator: defaultLenientSlotDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientSlotDigestEngine(flags)
        )
    }
}
