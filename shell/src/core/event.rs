use std::sync::mpsc::{self, Receiver, Sender};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Event {
    Shutdown,
}

pub struct EventBus {
    tx: Sender<Event>,
    rx: Receiver<Event>,
}

impl EventBus {
    pub fn new() -> Self {
        let (tx, rx) = mpsc::channel();
        Self { tx, rx }
    }

    pub fn sender(&self) -> Sender<Event> {
        self.tx.clone()
    }

    pub fn try_recv(&self) -> Option<Event> {
        self.rx.try_recv().ok()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sender_delivers_events() {
        let bus = EventBus::new();
        bus.sender().send(Event::Shutdown).unwrap();
        assert_eq!(bus.try_recv(), Some(Event::Shutdown));
    }
}
