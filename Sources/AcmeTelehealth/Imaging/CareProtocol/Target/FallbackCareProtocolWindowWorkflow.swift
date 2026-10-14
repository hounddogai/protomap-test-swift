import AcmePlatform
import Foundation

extension Imaging {
    /// Moves fallback care protocol windows through their life cycle and keeps a journal of what it did.
    final class FallbackCareProtocolWindowWorkflow {
        var store: any FallbackCareProtocolWindowStore
        var validator: FallbackCareProtocolWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackCareProtocolWindowEngine

        init(store: any FallbackCareProtocolWindowStore, validator: FallbackCareProtocolWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackCareProtocolWindowEngine) {
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
                throw Kit.Failure("fallback care protocol window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackCareProtocolWindowStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback care protocol window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackCareProtocolWindowStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback care protocol window \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newFallbackCareProtocolWindowWorkflow(_ store: any FallbackCareProtocolWindowStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackCareProtocolWindowWorkflow {
        return FallbackCareProtocolWindowWorkflow(
            store: store,
            validator: defaultFallbackCareProtocolWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackCareProtocolWindowEngine(flags)
        )
    }
}
