import AcmePlatform
import Foundation

extension Consent {
    /// Moves lenient proxy entries through their life cycle and keeps a journal of what it did.
    final class LenientProxyEntryDesk {
        var store: any LenientProxyEntryStore
        var validator: LenientProxyEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientProxyEntryEngine

        init(store: any LenientProxyEntryStore, validator: LenientProxyEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientProxyEntryEngine) {
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
                throw Kit.Failure("lenient proxy entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientProxyEntryStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient proxy entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientProxyEntryStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient proxy entry \(code) not found")
            }
            let result = engine.price(item)
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

    static func newLenientProxyEntryDesk(_ store: any LenientProxyEntryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientProxyEntryDesk {
        return LenientProxyEntryDesk(
            store: store,
            validator: defaultLenientProxyEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientProxyEntryEngine(flags)
        )
    }
}
