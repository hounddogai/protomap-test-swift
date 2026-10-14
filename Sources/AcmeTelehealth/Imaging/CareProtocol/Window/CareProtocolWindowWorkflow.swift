import AcmePlatform
import Foundation

extension Imaging {
    /// Moves care protocol windows through their life cycle and keeps a journal of what it did.
    final class CareProtocolWindowDesk {
        var store: any CareProtocolWindowStore
        var validator: CareProtocolWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareProtocolWindowEngine

        init(store: any CareProtocolWindowStore, validator: CareProtocolWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareProtocolWindowEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolWindowStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolWindowStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol window \(code) not found")
            }
            let result = engine.price(item)
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

    static func newCareProtocolWindowDesk(_ store: any CareProtocolWindowStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CareProtocolWindowDesk {
        return CareProtocolWindowDesk(
            store: store,
            validator: defaultCareProtocolWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareProtocolWindowEngine(flags)
        )
    }
}
